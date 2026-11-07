-- ZeDUI/tools/qa/claim_cards_sim.lua  (Nov 5 2026, QA): the safehouse, faction and wars cards with no game running.
-- The real Tokens, Tr, Atoms, Molecules, ZeD_ClaimProto, ZeD_ServerLink, ZeD_Claims, ZeD_TicketCards, ZeD_ClaimCards and
-- ServerTab, on Lua 5.1 stubs of a panel, text measures from the fonts' own sizes, the windows and the focus manager, with the
-- game's own words read from its install where it is there. It draws every state of mp_claim_cards.lua at the Deck and 720 sizes
-- (root 0.75), 1080p and 4K, Normal and Large text, mouse and pad; checks what drew (nothing past the drawer's edges, no field
-- outside its view, stops unique and whole, every grayed foot button saying why), then walks the flows with the game's calls
-- stubbed from their javap listings: the checker, claim, title, respawn, Add Player, a member's row, every foot confirm, create a
-- faction, tag, color, invitations as notes, the time left, wars, the controller. It proves the logic and the sums. What it cannot
-- prove is what the engine does: the text box, the keyboard, focus landing, real font widths.
-- This file's first half is ticket_cards_sim.lua's harness.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/claim_cards_sim.lua
-- It prints FAIL lines and a last line "claim_cards_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]claim_cards_sim%.lua$", "")

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
Joypad = {}
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
ISPlayerStatsUI = { opened = 0 }
function ISPlayerStatsUI:new()
    ISPlayerStatsUI.opened = ISPlayerStatsUI.opened + 1
    return { initialise = function() end, addToUIManager = function() end }
end
ISAdminMessage = { AddAdminMessage = function() end }

-- the files --------------------------------------------------------------------------------
local LOADED = {}
local STUBBED = { ["ZeD/ZeD_CharacterWindow"] = true, ["ZeD/ZeD_WorldWindow"] = true, ["ZeD/ZeD_TabPx"] = true, ["ZeD/ZeD_Messages"] = true, ["ZeD/SafeMode"] = true }
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
ZeD.Safe = { on = function() return false end }   -- (SafeMode.lua is stubbed: no safe mode, every screen ZeD's)
ZeD.Surface = nil
ZeD.Focus = { mark = function(panel, x, y, w, h, f) ZEDQA_MARKS = (ZEDQA_MARKS or 0) + 1; return true end }
ZeD.Messages = { ticket = function() end, ticketNew = function() end, invite = function(text) NOTES[#NOTES + 1] = text end }
ZeD.PadGlyphs = nil
ZeD.btnCase = function(s) return s end
ZeD.upper = function(s) return string.upper(s) end

local TABS = {}
ZeD_CharacterWindow = { addTab = function(def) TABS.server = def end }
ZeD_WorldWindow = { addTab = function(def) TABS.admin = def end }

local FOCUS = { id = nil, pad = false, soon = {} }
ZeD.Input = { Focus = {
    isFocused = function(_, _, id) return FOCUS.pad and id == FOCUS.id end,
    cuesVisible = function() return FOCUS.pad end,
    focusSoon = function(_, zone, pred) FOCUS.soon[#FOCUS.soon + 1] = { zone = zone, pred = pred } end,
    getFocusedWindow = function() return FOCUS.win end,
    getFocusedElement = function() return FOCUS.el end,
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
local TC, C, S, Tk, CC, K = ZeD.TicketCards, ZeD.Tickets, ZeD.ServerPart, ZeD.Tk, ZeD.ClaimCards, ZeD.Claims
ZeD.applyTheme("dark", "orange", "small")
check("the real files load", TC ~= nil and TABS.server ~= nil and TABS.admin ~= nil)

ZEDQA_CARDS_SIM = true
local Q = assert(loadfile(ROOT .. "ZeDUI/tools/qa/mp_claim_cards.lua"))()

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

-- every state ----------------------------------------------------------------------------
S.present, S.staff, S.admin = true, true, true
-- (one drawing first, so the tabs have their state)
local base = newPanel(480, 800)
frame("server", base, 480, 800)
frame("admin", base, 480, 800)
local states = Q.bind(CC, K, S, "Aretha", TC)
check("states to walk", #states >= 75, #states)

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
            s.reset(win, st)
            s.run(win, st)
            local p = panels[s.tab]
            WINS[s.tab]._tkFields = WINS[s.tab]._tkFields
            local ok, err = pcall(function()
                frame(s.tab, p, prof.w, prof.h)
                if Q.typed then CC.qaType(win, Q.typed[1], Q.typed[2]) end
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

-- the flows, with the game's calls under them ------------------------------------------------
TC.qaHold, K.qaHold, K.qaCaps, K.qaTaken, K.qaCanCreate, K.qaHours, K.qaOthers = nil, nil, nil, nil, nil, nil, nil
K.claim, K.info, K.safe, K.fac, K.wars = nil, {}, nil, nil, {}
K.sent, K.invites = { safe = {}, fac = {} }, {}
S.present, S.forceOff, S.staff, S.admin = true, nil, false, false
ZeD.ServerTab.players = { { user = "Rosa", name = "Rosa" }, { user = "Kade_R", name = "Kade_R" }, { user = "Mags_77", name = "Mags_77" } }
ZeD.ServerTab.askedAt = nowMs + 100000000
PLAYER.hours = 300
OPTS.Faction, OPTS.PlayerSafehouse, OPTS.SafehouseAllowRespawn, OPTS.War = true, true, true, true
OPTS.SafehouseDaySurvivedToClaim, OPTS.SafeHouseRemovalTime, OPTS.FactionDaySurvivedToCreate, OPTS.FactionPlayersRequiredForTag = 5, 72, 3, 3
OPTS.WarStartDelay, OPTS.WarDuration = 600, 3600

local W, H = 480, 800
local panel = newPanel(W, H)
local win, st = WINS.server, stOf("server")
win._tkFields = nil
local t = TC.qaState(st)
st.card, t.confirm, t.busy, t.flashText, t.items = nil, nil, nil, nil, nil
t.cl = {}
FOCUS.pad = false
ZEDQA_ROOT, ZEDQA_LARGE = 1, false
ZeD.applyTheme("dark", "orange", "small")

local function draw() frame("server", panel, W, H) end
local function tick(ms)
    nowMs = nowMs + (ms or 1100)
    for _, fn in ipairs(SYNCS) do fn() end
    SYNCS = {}
    for _, fn in ipairs(EVENTS.OnTick.list) do fn() end
end
local function settle() tick(); draw(); draw() end
local function stopOf(id)
    for _, e in ipairs(stops("server")) do if e.id == id then return e end end
    return nil
end
local function press(id)
    draw()
    local e = stopOf(id)
    check("the stop is there: " .. id, e ~= nil)
    if e then e.onActivate(win) end
    draw()
    return e
end
local function click(id)
    draw()
    local e = stopOf(id)
    check("clickable: " .. id, e ~= nil)
    if e then TABS.server.onClick(win, e.x + 1, e.y + 1) end
    draw()
end
local function field(key) return win._tkFields and win._tkFields[key] end
local function typeIn(key, text) field(key)._entry:setText(text); draw() end
local function footOf(id)
    for _, r in ipairs(t.footRects or {}) do if r.b.id == id then return r.b end end
    return nil
end
local function called(name)
    for i = #CALLS, 1, -1 do if CALLS[i].name == name then return CALLS[i] end end
    return nil
end
-- (a wrapped line is drawn in pieces: all of it read as one)
local function textDrawn(s)
    local parts = {}
    for _, x in ipairs(panel.texts) do parts[#parts + 1] = x.s end
    return string.find(table.concat(parts, " "), s, 1, true) ~= nil
end
local function gt(k, ...) return getText(k, ...) end

settle()
tick()
draw()

-- no safehouse: the checker in the tab -----------------------------------------------------
check("Can I claim this? shows", textDrawn(ZeD.tr("UI_ZeD_Cl_CanClaim")))
check("the answer is yes", K.claim and K.claim.ok == true)
check("Claim Safehouse is ready", stopOf("srv:claim") ~= nil)
check("the rules show without a safehouse", textDrawn(ZeD.tr("UI_ZeD_Cl_Rules")))
INSIDE = false
tick(2100)
draw()
draw()
check("outdoors: the game's reason", K.claim.lines[1] == gt("IGUI_Safehouse_NotInside"), K.claim.lines[1])
check("the reason shows", textDrawn(gt("IGUI_Safehouse_NotInside")))
do
    local dis = false
    for _, it in ipairs(st.items) do if it.k == "btn" and it.id == "claim" then dis = it.disabled and it.help == gt("IGUI_Safehouse_NotInside") end end
    check("Claim Safehouse is gray and says why", dis)
end
INSIDE = true
tick(2100)
draw()
draw()
CALLS = {}
press("srv:claim")
check("the game's claim, the username as title", called("sendSafehouseClaim") and called("sendSafehouseClaim").a[3] == "Aretha")
tick()
tick()
draw()
draw()
check("the new safehouse opens", st.card and st.card.kind == "safe")
check("its title is the field, ready", field("safeTitle") ~= nil and field("safeTitle"):getText() == "Aretha", field("safeTitle") and field("safeTitle"):getText())
check("the caret is in it", field("safeTitle")._entry:isFocused())
check("the help line says so", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Claimed"), ZeD.Help.last)

-- the title, Save in the foot ---------------------------------------------------------------
check("no Save until something is typed", footOf("save") == nil and footOf("release") ~= nil)
typeIn("safeTitle", "   ")
check("empty: Save is gray and says why", footOf("save") and footOf("save").disabled and footOf("save").why == ZeD.tr("UI_ZeD_Cl_TitleEmpty"))
typeIn("safeTitle", string.rep("x", 31))
check("too long: Save says why", footOf("save").why == ZeD.tr("UI_ZeD_Cl_TitleLong", 30))
typeIn("safeTitle", "Riverside Motel")
check("Save is ready", footOf("save") and not footOf("save").disabled)
check("Cancel sits beside it", footOf("ecancel") ~= nil)
draw()
check("no Release while words wait", footOf("release") == nil)
CALLS = {}
press("tk:ecancel")
check("Cancel puts it back", field("safeTitle"):getText() == "Aretha" and #CALLS == 0)
typeIn("safeTitle", "Riverside Motel")
CALLS = {}
press("tk:save")
check("Save is the game's call", called("sendSafehouseChangeTitle") and called("sendSafehouseChangeTitle").a[2] == "Riverside Motel")
draw()
check("it waits for the game", t.busy == true)
settle()
check("then says so", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Renamed"), ZeD.Help.last)
check("the foot is the card's again", footOf("save") == nil and footOf("release") ~= nil)
check("the field holds the new title", field("safeTitle"):getText() == "Riverside Motel")
typeIn("safeTitle", "By Enter")
CALLS = {}
field("safeTitle")._entry.onCommandEntered()
check("Enter saves", called("sendSafehouseChangeTitle") and called("sendSafehouseChangeTitle").a[2] == "By Enter")
settle()
typeIn("safeTitle", "By Escape")
field("safeTitle")._entry.onOtherKey(nil, Keyboard.KEY_ESCAPE)
draw()
check("Escape puts it back", field("safeTitle"):getText() == "By Enter")
typeIn("safeTitle", "Refused")
CALLS = {}
REFUSE = true
press("tk:save")
tick(9000)
draw()
REFUSE = nil
check("the game refusing is said", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_NoAnswer"), ZeD.Help.last)
check("and the words stay", field("safeTitle"):getText() == "Refused")
press("tk:ecancel")
draw()

-- a new character can rename: SafehouseChangeTitlePacket tests only that a title is there ---------
PLAYER.hours = 10
typeIn("safeTitle", "Too early")
check("too few days: Save still goes, as the game's window", footOf("save") and not footOf("save").disabled, footOf("save") and footOf("save").why)
PLAYER.hours = 300
press("tk:ecancel")

-- respawn -----------------------------------------------------------------------------------
CALLS = {}
press("tk:respawn")
check("respawn is the game's call", called("sendSafehouseChangeRespawn") and called("sendSafehouseChangeRespawn").a[2] == "Aretha" and called("sendSafehouseChangeRespawn").a[3] == true)
settle()
OPTS.SafehouseAllowRespawn = false
settle()
do
    local e = stopOf("tk:respawn")
    check("off on this server: the tick is gray and says why", e and e.tkWhy() == ZeD.tr("UI_ZeD_Cl_RespawnOff"))
    CALLS = {}
    press("tk:respawn")
    check("a gray tick does nothing", #CALLS == 0)
end
OPTS.SafehouseAllowRespawn = true
settle()

-- Add Player --------------------------------------------------------------------------------
check("no drawer yet", stopOf("tk:pick:Rosa") == nil)
press("tk:add")
check("the drawer opens: who's online", stopOf("tk:pick:Rosa") ~= nil and stopOf("tk:pick:Kade_R") ~= nil)
check("it is in the card, not a window", textDrawn(ZeD.tr("UI_ZeD_Cl_PlayersOnline")))
press("tk:add")
check("the same press closes it", stopOf("tk:pick:Rosa") == nil)
press("tk:add")
OTHER.Kade_R = true
K.bump()
settle()
do
    local e = stopOf("tk:pick:Kade_R")
    check("someone with a safehouse: gray, in the game's words", e and e.tkWhy() == gt("IGUI_SafehouseUI_AlreadyHaveSafehouse", "(Their place)"), e and e.tkWhy())
    CALLS = {}
    e.onActivate(win)
    check("gray does nothing", #CALLS == 0)
end
OTHER.Kade_R = nil
CALLS = {}
press("tk:pick:Rosa")
check("the game's invitation", called("sendSafehouseInvite") and called("sendSafehouseInvite").a[3] == "Rosa")
check("the drawer closes", stopOf("tk:pick:Mags_77") == nil)
check("it says so", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Sent", "Rosa"), ZeD.Help.last)
settle()
check("she waits on the list", textDrawn(ZeD.tr("UI_ZeD_Cl_InvitedWaiting")))
check("Cancel takes it back", stopOf("tk:un:Rosa") ~= nil)
CLIENT = {}
press("tk:un:Rosa")
check("through the server part", CLIENT[#CLIENT] and CLIENT[#CLIENT].c == "c_cancel" and CLIENT[#CLIENT].a.who == "Rosa")
S.routes[ZeD.Cl.MOD]("c_ack", { ok = true, rid = CLIENT[#CLIENT].a.rid })
settle()
check("gone from the list", stopOf("tk:un:Rosa") == nil)
K.invite("safe", "Rosa")
S.forceOff = true
K.bump()
settle()
do
    local e = stopOf("tk:un:Rosa")
    check("no server part: gray, and says why", e and e.tkWhy() == ZeD.tr("UI_ZeD_Cl_NoTakeBack"), e and e.tkWhy())
end
S.forceOff = nil
K.sent.safe = {}
K.bump()
settle()

-- a member's row ----------------------------------------------------------------------------
GS[1].players[#GS[1].players + 1] = "Rosa"
GS[1].players[#GS[1].players + 1] = "Gone_Guy"
settle()
check("my own row has nothing to pick", stopOf("tk:m:Aretha") ~= nil and stopOf("tk:m:Aretha").promptA == false)
check("the row shows the owner", textDrawn("OWNER"))
check("no buttons yet", stopOf("tk:own:Rosa") == nil)
press("tk:m:Rosa")
check("picked: Change Owner and Remove", stopOf("tk:own:Rosa") ~= nil and stopOf("tk:rem:Rosa") ~= nil)
press("tk:m:Rosa")
check("picked again: gone", stopOf("tk:own:Rosa") == nil)
click("tk:m:Gone_Guy")
do
    local e = stopOf("tk:own:Gone_Guy")
    check("offline: Change Owner says why", e and e.tkWhy() == ZeD.tr("UI_ZeD_Cl_MustBeOnline", "Gone_Guy"), e and e.tkWhy())
end
press("tk:m:Gone_Guy")
press("tk:m:Rosa")
press("tk:rem:Rosa")
check("Remove asks in the foot, in the game's words", t.confirm ~= nil and panel ~= nil and textDrawn(gt("IGUI_SafehouseUI_RemoveConfirm", "Rosa")), t.confirm and t.confirm.act)
check("the foot has the answer buttons", footOf("no") ~= nil and footOf("yes") ~= nil)
stopOf("tk:no").onCancel(win)
draw()
check("B keeps it", t.confirm == nil)
press("tk:rem:Rosa")
press("tk:no")
check("Keep keeps it", t.confirm == nil and #GS[1].players == 3)
press("tk:rem:Rosa")
CALLS = {}
press("tk:yes")
check("Remove is the game's call", called("sendSafehouseChangeMember") and called("sendSafehouseChangeMember").a[2] == "Rosa")
settle()
check("she's gone", #GS[1].players == 2 and ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Removed", "Rosa"), ZeD.Help.last)
GS[1].players[#GS[1].players + 1] = "Kade_R"
settle()
press("tk:m:Kade_R")
press("tk:own:Kade_R")
check("Change Owner asks", textDrawn(ZeD.tr("UI_ZeD_Cl_OwnerAsk", "Kade_R")))
CALLS = {}
press("tk:yes")
check("the game's call", called("sendSafehouseChangeOwner") and called("sendSafehouseChangeOwner").a[2] == "Kade_R")
settle()
check("I'm a member now: the title is read only", field("safeTitle"):isVisible() == false or st.card.kind == "safe")
check("Quit, not Release", footOf("quit") ~= nil and footOf("release") == nil)
press("tk:quit")
check("Quit asks, in the game's words", textDrawn(gt("IGUI_SafehouseUI_QuitSafeConfirm")))
CALLS = {}
press("tk:yes")
settle()
check("gone: back in the tab", st.card == nil)
check("it says so", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Quit"), ZeD.Help.last)
check("the checker is back", stopOf("srv:claim") ~= nil)

-- release -----------------------------------------------------------------------------------
press("srv:claim")
tick()
tick()
draw()
check("a second claim opens", st.card and st.card.kind == "safe")
press("tk:release")
check("Release asks, in the game's words", textDrawn(gt("IGUI_SafehouseUI_ReleaseConfirm")))
do
    local e = stopOf("tk:no")
    check("the question is whole, not cut", textDrawn(gt("IGUI_SafehouseUI_ReleaseConfirm")))
    check("every stop has the card's B", e and e.onCancel ~= nil)
end
CALLS = {}
press("tk:yes")
check("the game's release", called("sendSafehouseRelease") ~= nil)
settle()
check("released", st.card == nil and ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Released"), ZeD.Help.last)

-- create a faction --------------------------------------------------------------------------
OPTS.Faction = false
settle()
do
    local e = stopOf("srv:faction")
    check("factions off: gray, the game's words", e and e.help == gt("IGUI_FactionUI_Disabled"), e and e.help)
end
OPTS.Faction = true
PLAYER.hours = 10
K.bump()
settle()
do
    local e = stopOf("srv:faction")
    check("too soon: gray, the game's words", e and e.help == gt("IGUI_FactionUI_FactionSurvivalDay", 3), e and e.help)
    e.onActivate(win)
    draw()
    check("gray does nothing", st.card == nil)
end
PLAYER.hours = 300
K.bump()
settle()
press("srv:faction")
check("Create opens in the card", st.card and st.card.kind == "newfac")
draw()
check("the name is a field", field("newFac") ~= nil)
check("Create is gray with nothing typed", footOf("create") and footOf("create").disabled and footOf("create").why == ZeD.tr("UI_ZeD_Cl_NameFirst"))
typeIn("newFac", "Ri")
check("2: the game's words", footOf("create").why == gt("IGUI_FactionUI_FactionNameTooLongShort"))
typeIn("newFac", "Riverside Farmers")
check("17: the game's words", footOf("create").why == gt("IGUI_FactionUI_FactionNameTooLongShort"))
GF[1] = newFaction("Muldraugh Mall", "Mags")
typeIn("newFac", "Muldraugh Mall")
check("taken: the game's words", footOf("create").why == gt("IGUI_FactionUI_FactionAlreadyExist"))
table.remove(GF, 1)
typeIn("newFac", "Riverside")
check("ready", not footOf("create").disabled)
CALLS = {}
press("tk:create")
check("the game's call", called("sendFactionCreate") and called("sendFactionCreate").a[1] == "Riverside" and called("sendFactionCreate").a[2] == "Aretha")
settle()
settle()
check("it becomes the faction's card", st.card and st.card.kind == "faction")
check("it says so", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Created", "Riverside"), ZeD.Help.last)

-- the faction card --------------------------------------------------------------------------
check("too few for a tag: the game's words", textDrawn(gt("IGUI_FactionUI_TagMembersIncorrect", 3)))
GF[1].players = { "Rosa", "Kade_R" }
settle()
check("the tag field opens at three", field("facTag") ~= nil and stopOf("tk:f:facTag") ~= nil)
do
    local e = stopOf("tk:col:Green")
    check("a color needs a tag", e and e.tkWhy() == ZeD.tr("UI_ZeD_Cl_TagFirst"))
end
typeIn("facTag", "rvf")
check("the count as you type", textDrawn(ZeD.tr("UI_ZeD_Cl_Count", 3, 4)))
typeIn("facTag", "rvfar")
check("5: the game's words", footOf("save").why == gt("IGUI_FactionUI_TagTooLongShort"))
typeIn("facTag", "rvf")
CALLS = {}
press("tk:save")
check("sent, and only the server's answer writes it here", GF[1].tag == nil and called("sendFactionChangeTag") ~= nil, GF[1].tag)
settle()
check("in capitals", K.fac.tag == "RVF" and GF[1].tag == "RVF")
check("it says so when it has come back", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_TagSet"), ZeD.Help.last)
check("the preview shows", textDrawn(ZeD.tr("UI_ZeD_Cl_OverHead")))
CALLS = {}
press("tk:col:Green")
check("a color is the game's call", called("sendFactionChangeTag") ~= nil)
settle()
check("and it comes back", math.abs(GF[1].color:getG() - 0.604) < 0.01)
CALLS = {}
press("tk:showtag")
check("show tag: the player's, the game's call", PLAYER.showTag == false and called("sendFactionStatsChange") ~= nil)
press("tk:pvp")
check("PvP: the same", PLAYER.pvp == true)
settle()
typeIn("facName", "Ri")
check("rename checks too", footOf("save").why == gt("IGUI_FactionUI_FactionNameTooLongShort"))
typeIn("facName", "Riverfolk")
typeIn("facTag", "RVR")
CALLS = {}
press("tk:save")
settle()
settle()
check("both fields save", GF[1].name == "Riverfolk" and GF[1].tag == "RVR")
press("tk:add")
check("a faction's drawer", stopOf("tk:pick:Mags_77") ~= nil)
CALLS = {}
press("tk:pick:Mags_77")
check("the game's invitation", called("sendFactionInvite") and called("sendFactionInvite").a[3] == "Mags_77")
K.sent.fac = {}
K.bump()
settle()
press("tk:m:Rosa")
press("tk:rem:Rosa")
check("the game's words", textDrawn(gt("IGUI_FactionUI_RemoveConfirm", "Rosa")))
CALLS = {}
press("tk:yes")
check("the game's call", called("sendFactionRemoveMember") and called("sendFactionRemoveMember").a[2] == "Rosa")
settle()
press("tk:m:Kade_R")
press("tk:own:Kade_R")
CALLS = {}
press("tk:yes")
check("the game's call", called("sendFactionChangeOwner") and called("sendFactionChangeOwner").a[2] == "Kade_R")
settle()
check("a member now: Leave", footOf("leave") ~= nil and footOf("disband") == nil)
check("the name is read only", stopOf("tk:f:facName") == nil)
check("my two ticks stay mine", stopOf("tk:showtag") ~= nil and stopOf("tk:pvp") ~= nil)
press("tk:leave")
check("Leave asks, in the game's words", textDrawn(gt("IGUI_FactionUI_QuitSafeConfirm")))
press("tk:yes")
settle()
check("left", st.card == nil and ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Left"), ZeD.Help.last)
GF[1] = nil
K.bump()
settle()

-- Disband ----------------------------------------------------------------------------------
press("srv:faction")
draw()
typeIn("newFac", "Second")
press("tk:create")
settle()
settle()
press("tk:disband")
check("Disband asks, in the game's words", textDrawn(gt("IGUI_FactionUI_DisbandConfirm")))
CALLS = {}
press("tk:yes")
check("the game's call", called("sendFactionDisband") ~= nil)
settle()
check("disbanded", st.card == nil and ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Disbanded"), ZeD.Help.last)

-- invitations: a note, never a modal ------------------------------------------------------
do
    local f = newFaction("Muldraugh Mall", "Mags_77")
    MODALS = 0
    EVENTS.ReceiveFactionInvite.list[#EVENTS.ReceiveFactionInvite.list](f, "Mags_77", "Aretha")
    settle()
    check("a note in the tab", textDrawn(ZeD.tr("UI_ZeD_Cl_NoteSub")))
    check("in the game's words", textDrawn(ZeD.tr("UI_ZeD_Cl_InviteFaction", "Mags_77", "Muldraugh Mall")))
    check("the belt has it", NOTES[#NOTES] == ZeD.tr("UI_ZeD_Cl_InviteFaction", "Mags_77", "Muldraugh Mall"))
    check("Decline and Accept are stops", stopOf("srv:tk:inv:no:1") ~= nil and stopOf("srv:tk:inv:yes:1") ~= nil)
    CALLS = {}
    press("srv:tk:inv:no:1")
    check("Decline: the game's answer", called("acceptFactionInvite") and called("acceptFactionInvite").a[4] == false)
    settle()
    check("the note goes", #K.invites == 0)
    check("it says so", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Declined", "Mags_77"), ZeD.Help.last)
    EVENTS.ReceiveFactionInvite.list[#EVENTS.ReceiveFactionInvite.list](f, "Mags_77", "Aretha")
    settle()
    CALLS = {}
    click("srv:tk:inv:yes:1")
    check("Accept by mouse: the game's answer", called("acceptFactionInvite") and called("acceptFactionInvite").a[4] == true)
    f.players[#f.players + 1] = "Aretha"
    settle()
    check("in", K.fac ~= nil and #K.invites == 0)
    check("it says so", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Joined", "Muldraugh Mall"), ZeD.Help.last)
    table.remove(GF, 1)
    settle()
    local s = newSafe(10, 10, 10, 10, "Rosa")
    EVENTS.ReceiveSafehouseInvite.list[#EVENTS.ReceiveSafehouseInvite.list](s, "Rosa", "Aretha")
    settle()
    check("a safehouse's note", textDrawn(ZeD.tr("UI_ZeD_Cl_InviteSafe", "Rosa")))
    CALLS = {}
    press("srv:tk:inv:yes:1")
    check("Accept: the game's answer", called("acceptSafehouseInvite") and called("acceptSafehouseInvite").a[4] == true)
    -- the review, Nov 7: a second Accept while the first is on its way says to wait, not that it is gone
    local s2 = newSafe(40, 40, 10, 10, "Kade_R")
    EVENTS.ReceiveSafehouseInvite.list[#EVENTS.ReceiveSafehouseInvite.list](s2, "Kade_R", "Aretha")
    settle()
    CALLS = {}
    press("srv:tk:inv:yes:1")
    check("a held Accept sends nothing", called("acceptSafehouseInvite") == nil)
    check("and says to wait", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_AnswerWait"), ZeD.Help.last)
    table.insert(s.players, "Aretha")
    settle()
    check("the first lands", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Joined", gt("IGUI_SafehouseUI_Safehouse")), ZeD.Help.last)
    check("and the waiting note goes with it", #K.invites == 0, #K.invites)
    check("the summary row opens the card", stopOf("srv:tk:sum:safe") ~= nil)
    press("srv:tk:sum:safe")
    check("the card", st.card and st.card.kind == "safe")
    check("a member's title is not a field", stopOf("tk:f:safeTitle") == nil)
    settle()
    t.confirm = nil
    TC.back(win, st)
    draw()
end

-- the time left -----------------------------------------------------------------------------
S.routes[ZeD.Cl.MOD]("c_info", { safe = { visitedH = 61 }, invites = { n = 0 } })
settle()
check("under two days it shows in the tab", textDrawn(ZeD.tr("UI_ZeD_Cl_KeepHours", 11)), ZeD.tr("UI_ZeD_Cl_KeepHours", 11))
press("srv:tk:sum:safe")
check("and on the card", textDrawn(ZeD.tr("UI_ZeD_Cl_KeepHours", 11)))
S.routes[ZeD.Cl.MOD]("c_info", { safe = { visitedH = 2 }, invites = { n = 0 } })
settle()
check("days from two days up", textDrawn(ZeD.tr("UI_ZeD_Cl_KeepDays", 2)))
S.routes[ZeD.Cl.MOD]("c_info", { safe = { visitedH = 71.9 }, invites = { n = 0 } })
settle()
check("the last hour", textDrawn(ZeD.tr("UI_ZeD_Cl_KeepSoon")))
TC.back(win, st)
draw()
GS = {}
K.dirty = true
settle()

-- wars --------------------------------------------------------------------------------------
do
    OPTS.War = false
    settle()
    check("no wars on the server: no block", stopOf("srv:tk:sum:wars") == nil)
    OPTS.War = true
    settle()
    check("wars on: the block", stopOf("srv:tk:sum:wars") ~= nil)
    press("srv:tk:sum:wars")
    check("the wars card", st.card and st.card.kind == "wars")
    check("none yet", textDrawn(ZeD.tr("UI_ZeD_Cl_NoWars")))
    TC.back(win, st)
    draw()
    local s = newSafe(10, 10, 10, 10, "Aretha")
    s.title = "Riverside Motel"
    WARS[1] = newWar(s, "Kade_R", "Claimed", "00:09:00")
    settle()
    press("srv:tk:sum:wars")
    check("the safehouse, the two sides", textDrawn("Riverside Motel") and textDrawn(gt("IGUI_WarManager_You")) and textDrawn("Kade_R"))
    check("the countdown, the game's words", textDrawn(gt("IGUI_WarManager_TimeToAccept", "00:09:00")))
    local id = "tk:w:" .. tostring(s.onlineId) .. ":Kade_R:"
    check("the defender accepts or refuses", stopOf(id .. "Accepted") ~= nil and stopOf(id .. "Refused") ~= nil)
    check("no End for a player", stopOf(id .. "Ended") == nil)
    press(id .. "Accepted")
    check("Accept asks in the foot", t.confirm ~= nil and textDrawn(ZeD.tr("UI_ZeD_Cl_WarAcceptAsk", "Kade_R")))
    press("tk:no")
    check("Keep keeps it", t.confirm == nil)
    CALLS = {}
    press(id .. "Accepted")
    press("tk:yes")
    check("the game's call", called("sendWarManagerUpdate") and called("sendWarManagerUpdate").a[1] == s.onlineId and called("sendWarManagerUpdate").a[2] == "Kade_R"
        and called("sendWarManagerUpdate").a[3] == "Accepted")
    WARS[1].state = "Accepted"
    settle()
    check("it moves on", textDrawn(gt("IGUI_WarManager_TimeToStart", "00:09:00")))
    WARS[1].state = "Claimed"
    settle()
    CALLS = {}
    press(id .. "Refused")
    check("Refuse goes at once, as the game's window", called("sendWarManagerUpdate") and called("sendWarManagerUpdate").a[3] == "Refused")
    WARS[1].state = "Started"
    ZEDQA_CAPS.CanGoInsideSafehouses = true
    K.bump()
    settle()
    press(id .. "Ended")
    check("End asks", textDrawn(ZeD.tr("UI_ZeD_Cl_WarEndAsk")))
    CALLS = {}
    press("tk:yes")
    check("End is the game's call", called("sendWarManagerUpdate") and called("sendWarManagerUpdate").a[3] == "Ended")
    ZEDQA_CAPS.CanGoInsideSafehouses = nil
    TC.back(win, st)
    draw()
    WARS[1] = nil
    GS = {}
    K.dirty = true
    settle()
end

-- the controller ----------------------------------------------------------------------------
FOCUS.pad = true
draw()
press("srv:claim")
tick()
tick()
draw()
draw()
FOCUS.soon = {}
do
    local e = stopOf("tk:f:safeTitle")
    check("the title is a stop under the controller", e ~= nil)
    check("it is the stop the card lands on", e.tkLand == true)
    e.onActivate(win)
    draw()
    typeIn("safeTitle", "By pad")
    check("words typed: the foot's Save takes the focus", (function()
        for _, s in ipairs(FOCUS.soon) do
            if s.pred({ id = "tk:save" }) then return true end
        end
        return false
    end)())
    press("tk:save")
    settle()
    check("saved under the controller", GS[1].title == "By pad")
    typeIn("safeTitle", "Into B")
    local b = stopOf("tk:f:safeTitle")
    b.onCancel(win)
    draw()
    check("B puts the words back and stays on the card", st.card ~= nil and field("safeTitle"):getText() == "By pad")
    b = stopOf("tk:release")
    b.onCancel(win)
    draw()
    check("B again leaves the card", st.card == nil)
    press("srv:tk:sum:safe")
    check("every stop answers to B", (function()
        for _, e2 in ipairs(stops("server")) do if not e2.onCancel then return false end end
        return true
    end)())
    press("tk:release")
    draw()
    FOCUS.id = "tk:no"
    draw()
    check("under the controller the question is whole", textDrawn(gt("IGUI_SafehouseUI_ReleaseConfirm")))
    stopOf("tk:yes").onActivate(win)
    settle()
    check("released under the controller", st.card == nil)
end
FOCUS.pad = false

-- the right-click menu's View safehouse -----------------------------------------------------
do
    local got = nil
    ISWorldObjectContextMenu = { onViewSafeHouse = function() got = "game" end }
    CC.hookWorld()
    local s = newSafe(10, 10, 10, 10, "Aretha")
    K.dirty = true
    settle()
    local openedTab = nil
    ZeD_CharacterWindow.openTab = function(_, id) openedTab = id; return true end
    ISWorldObjectContextMenu.onViewSafeHouse(nil, s, PLAYER)
    draw()
    check("mine opens the card", got == nil and openedTab == "server" and st.card and st.card.kind == "safe")
    TC.back(win, st)
    draw()
    ISWorldObjectContextMenu.onViewSafeHouse(nil, { other = true }, PLAYER)
    check("someone else's is the game's window", got == "game")
end

-- the review's cases ------------------------------------------------------------------------
local function stale() return ZeD.tr("UI_ZeD_Cl_AskStale") end
local function clearWorld()
    if st.card then TC.back(win, st) end
    GS, GF, WARS = {}, {}, {}
    K.dirty = true
    K.invites, K.sent, K.sentSure = {}, { safe = {}, fac = {} }, {}
    settle()
end
local function home(names)
    clearWorld()
    local s = newSafe(10, 10, 10, 10, "Aretha")
    s.title = "Home"
    for _, n in ipairs(names or {}) do s.players[#s.players + 1] = n end
    K.dirty = true
    settle()
    press("srv:tk:sum:safe")
    return s
end
local function drop(s, name)
    for i = #s.players, 1, -1 do if s.players[i] == name then table.remove(s.players, i) end end
end

-- a confirm left open: the game's anti-cheat kicks on the first refused safehouse packet
do
    local s = home({ "Rosa" })
    press("tk:m:Rosa")
    press("tk:rem:Rosa")
    check("Remove is up", t.confirm ~= nil and footOf("yes") ~= nil)
    drop(s, "Rosa")
    settle()
    check("she quit: it closes by itself", t.confirm == nil and footOf("yes") == nil)
    check("and says so", ZeD.Help.last == stale(), ZeD.Help.last)
    s.players[#s.players + 1] = "Rosa"
    settle()
    press("tk:m:Rosa")
    press("tk:rem:Rosa")
    drop(s, "Rosa")
    CALLS = {}
    press("tk:yes")
    check("she quit in the last second: the press reads the game first and sends nothing", #CALLS == 0 and t.confirm == nil, #CALLS)
    settle()
    press("tk:release")
    s.owner = "Rosa"
    s.players = { "Aretha", "Rosa" }
    settle()
    check("the house went to someone else: Release closes", t.confirm == nil and footOf("yes") == nil)
    check("nothing to release now", footOf("release") == nil and footOf("quit") ~= nil)
    s.owner = "Aretha"
    settle()
    press("tk:release")
    s.owner = "Rosa"
    CALLS = {}
    press("tk:yes")
    check("and in the last second", called("sendSafehouseRelease") == nil)
    s.owner = "Aretha"
    s.players = { "Aretha", "Rosa", "Kade_R" }
    settle()
    press("tk:m:Kade_R")
    press("tk:own:Kade_R")
    drop(s, "Kade_R")
    settle()
    check("Change Owner on someone who quit closes", t.confirm == nil and footOf("yes") == nil)
    s.players[#s.players + 1] = "Kade_R"
    settle()
    press("tk:m:Kade_R")
    press("tk:own:Kade_R")
    local online = ZeD.ServerTab.players
    ZeD.ServerTab.players = { { user = "Rosa", name = "Rosa" } }
    settle()
    check("Change Owner on someone gone offline closes", t.confirm == nil)
    ZeD.ServerTab.players = online
    settle()
    -- Keep goes back to the button pressed
    press("tk:m:Kade_R")
    press("tk:own:Kade_R")
    FOCUS.soon = {}
    press("tk:no")
    local hit, wrong = false, false
    for _, x in ipairs(FOCUS.soon) do
        if x.pred({ id = "tk:own:Kade_R" }) then hit = true end
        if x.pred({ id = "tk:rem:Kade_R" }) then wrong = true end
    end
    check("Keep on Change Owner lands on Change Owner", hit and not wrong)
end
do
    clearWorld()
    local s = newSafe(10, 10, 10, 10, "Aretha")
    s.title = "Motel"
    WARS[1] = newWar(s, "Kade_R", "Claimed", "00:09:00")
    K.dirty = true
    settle()
    check("the row's second line is the nearest countdown", textDrawn(gt("IGUI_WarManager_TimeToAccept", "00:09:00")))
    press("srv:tk:sum:wars")
    local id = "tk:w:" .. tostring(s.onlineId) .. ":Kade_R:Accepted"
    press(id)
    check("Accept is up", t.confirm ~= nil)
    WARS[1].state = "Canceled"
    settle()
    check("the war moved on: Accept closes", t.confirm == nil and footOf("yes") == nil)
    WARS[1].state = "Claimed"
    settle()
    press(id)
    WARS[1] = nil
    K.dirty = true
    settle()
    check("the war left the list: the same", t.confirm == nil)
    TC.back(win, st)
    draw()
end

-- staff with two safehouses
do
    ZEDQA_CAPS.CanSetupSafehouses = true
    local a = home()
    local b = newSafe(30, 30, 10, 10, "Aretha")
    K.dirty = true
    settle()
    press("tk:release")
    for i = #GS, 1, -1 do if GS[i] == a then table.remove(GS, i) end end
    settle()
    check("the house went: its confirm does not move to the other", t.confirm == nil and footOf("yes") == nil and #GS == 1)
    TC.back(win, st)
    draw()
    GS = { a, b }
    K.dirty = true
    settle()
    press("srv:tk:sum:safe")
    press("tk:release")
    CALLS = {}
    press("tk:yes")
    check("the one asked about goes", called("sendSafehouseRelease").a[1] == a)
    settle()
    settle()
    check("told it went, not told it failed", ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_Released"), ZeD.Help.last)
    check("the other is not put in front of Release", st.card == nil and #GS == 1 and GS[1] == b)
    ZEDQA_CAPS.CanSetupSafehouses = nil
end

-- staff who are members, not owners
do
    clearWorld()
    ZEDQA_CAPS.CanSetupSafehouses, ZEDQA_CAPS.FactionCheat = true, true
    local s = newSafe(10, 10, 10, 10, "Rosa")
    s.players = { "Rosa", "Aretha" }
    local f = newFaction("Theirs", "Rosa")
    f.players = { "Aretha", "Kade_R" }
    K.dirty = true
    settle()
    press("srv:tk:sum:safe")
    check("staff, a member: Quit and Release", footOf("quit") ~= nil and footOf("release") ~= nil)
    press("tk:release")
    CALLS = {}
    press("tk:yes")
    check("Release is the game's call", called("sendSafehouseRelease") ~= nil)
    settle()
    press("srv:tk:sum:fac")
    check("staff, a member: Leave and Disband", footOf("leave") ~= nil and footOf("disband") ~= nil)
    TC.back(win, st)
    draw()
    ZEDQA_CAPS.CanSetupSafehouses, ZEDQA_CAPS.FactionCheat = nil, nil
end

-- what the game holds that ZeD would have typed differently is not an edit
do
    clearWorld()
    OPTS.FactionPlayersRequiredForTag = 1
    local f = newFaction("Ours", "Aretha")
    f.tag = "mg"
    K.dirty = true
    settle()
    press("srv:tk:sum:fac")
    draw()
    check("a lower-case tag from the game's window: the quiet foot", footOf("disband") ~= nil and footOf("save") == nil)
    check("shown as stored", field("facTag"):getText() == "mg")
    stopOf("tk:disband").onCancel(win)
    draw()
    check("B leaves the card", st.card == nil)
    press("srv:tk:sum:fac")
    typeIn("facTag", "mgr")
    check("an edit is one", footOf("save") ~= nil)
    press("tk:ecancel")
    check("Cancel puts it back as stored", field("facTag"):getText() == "mg" and footOf("disband") ~= nil)
    OPTS.FactionPlayersRequiredForTag = 3
    local s = home()
    s.title = "Home "
    K.dirty = true
    settle()
    draw()
    check("a title with a space on the end: Release stays", footOf("release") ~= nil and footOf("save") == nil)
    check("too few for a tag, staff or not", (function()
        clearWorld()
        ZEDQA_CAPS.FactionCheat = true
        newFaction("Small", "Aretha")
        K.dirty = true
        settle()
        press("srv:tk:sum:fac")
        local gray = stopOf("tk:f:facTag") == nil and stopOf("tk:col:Green") == nil
        ZEDQA_CAPS.FactionCheat = nil
        return gray
    end)())
end

-- the fields, as drawn
do
    local s = home()
    field("safeTitle")._entry:focus()
    draw()
    draw()
    check("typing: the count", textDrawn(ZeD.tr("UI_ZeD_Cl_Count", 4, 30)))
    check("not pick to rename", not textDrawn(ZeD.tr("UI_ZeD_Cl_PickRename")))
    check("the drawing's line under it", textDrawn(ZeD.tr("UI_ZeD_Cl_TitleSub")))
    typeIn("safeTitle", "")
    draw()
    check("a problem takes its place", textDrawn(ZeD.tr("UI_ZeD_Cl_TitleEmpty")) and not textDrawn(ZeD.tr("UI_ZeD_Cl_TitleSub")))
    press("tk:ecancel")
    field("safeTitle")._entry:unfocus()
    draw()
    draw()
    check("left alone: pick to rename, and no line", textDrawn(ZeD.tr("UI_ZeD_Cl_PickRename")) and not textDrawn(ZeD.tr("UI_ZeD_Cl_TitleSub")))
    check("one name reads as one", (function()
        TC.back(win, st)
        draw()
        return textDrawn(ZeD.tr("UI_ZeD_Cl_OnePlayer")) and not textDrawn("1 players")
    end)())
end

-- Enter and Escape in Create Faction
do
    clearWorld()
    press("srv:faction")
    draw()
    typeIn("newFac", "Enterprise")
    CALLS = {}
    field("newFac")._entry.onCommandEntered()
    check("Enter creates", called("sendFactionCreate") and called("sendFactionCreate").a[1] == "Enterprise")
    settle()
    settle()
    clearWorld()
    press("srv:faction")
    draw()
    typeIn("newFac", "x")
    CALLS = {}
    field("newFac")._entry.onCommandEntered()
    check("Enter on a bad name does nothing", #CALLS == 0 and st.card ~= nil)
    field("newFac")._entry.onOtherKey(nil, Keyboard.KEY_ESCAPE)
    draw()
    check("Escape backs out", st.card == nil)
end

-- the server's rules
do
    OPTS.SafeHouseRemovalTime = 0
    clearWorld()
    tick(2100)
    draw()
    draw()
    check("no expiry on this server: it says so", textDrawn(ZeD.tr("UI_ZeD_Cl_RuleRemovalOff")) and not textDrawn("real hours"))
    OPTS.SafeHouseRemovalTime = 72
    settle()
    check("the tab's rules are stops", stopOf("srv:tk:rule:1") ~= nil and stopOf("srv:tk:rule:1").promptA == false and stopOf("srv:tk:rule:8") ~= nil)
    do
        local e = stopOf("srv:tk:rule:8")
        check("each knows where it sits", type(e.cy) == "number")
        FOCUS.id, FOCUS.el, FOCUS.win = e.id, e, win
        draw()
        FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
    end
    press("srv:faction")
    draw()
    do
        local n = 0
        for _, e in ipairs(stops("server")) do
            if string.find(e.id, "tk:rule:", 1, true) then
                n = n + 1
                check("nothing to press on a rule", e.promptA == false and e.onCancel ~= nil)
            end
        end
        check("Create Faction's lines are stops", n >= 2, n)
    end
    TC.back(win, st)
    draw()
    home()
    do
        local n = 0
        for _, e in ipairs(stops("server")) do
            if string.find(e.id, "tk:rule:", 1, true) then n = n + 1 end
        end
        check("the card's rules are stops", n == 8, n)
    end
    TC.back(win, st)
    draw()
end

-- a player passes the day to create a faction with nothing else changing
do
    clearWorld()
    newSafe(10, 10, 10, 10, "Aretha")
    PLAYER.hours = 10
    K.dirty = true
    settle()
    check("day 1: gray", stopOf("srv:faction") and stopOf("srv:faction").help == gt("IGUI_FactionUI_FactionSurvivalDay", 3))
    PLAYER.hours = 100
    settle()
    settle()
    check("day 4: it opens by itself", stopOf("srv:faction").help ~= gt("IGUI_FactionUI_FactionSurvivalDay", 3), stopOf("srv:faction").help)
    PLAYER.hours = 300
end

-- the note's Open with a card left open over it
do
    local s = home()
    local f = newFaction("Mall", "Mags_77")
    K.addInvite("fac", f, "Aretha")
    settle()
    check("the card is up", st.card ~= nil)
    FOCUS.soon = {}
    K.openNext = "invite"
    draw()
    draw()
    check("Open leaves the card, for the note", st.card == nil and textDrawn(ZeD.tr("UI_ZeD_Cl_NoteSub")))
    local hit = false
    for _, x in ipairs(FOCUS.soon) do
        if x.pred({ id = "srv:tk:inv:yes:1" }) then hit = true end
    end
    check("the hand lands on Accept", hit)
end

-- the Admin tab keeps every safehouse and faction: the cards read only your own, which opens its card
do
    clearWorld()
    local mine = newSafe(10, 10, 10, 10, "Aretha")
    newSafe(40, 40, 10, 10, "Rosa")
    newFaction("Riverside", "Aretha")
    newFaction("Mall", "Rosa")
    K.dirty = true
    settle()
    check("yours is yours", K.safe and K.safe.obj == mine and K.fac ~= nil)
    ZEDQA_CAPS.CanSetupSafehouses, ZEDQA_CAPS.FactionCheat = true, true
    local openedTab, gameWin = nil, nil
    ZeD_CharacterWindow.openTab = function(_, id) openedTab = id; return true end
    local oldS, oldF = ISSafehouseUI, ISFactionUI
    local function game(name)
        return { new = function()
            gameWin = name
            return { initialise = function() end, addToUIManager = function() end }
        end }
    end
    ISSafehouseUI, ISFactionUI = game("safehouse"), game("faction")
    local function adminStop(id)
        frame("admin", panel, W, H)
        for _, e in ipairs(stops("admin")) do if e.id == id then return e end end
        check("the Admin tab's stop is there: " .. id, false)
        return nil
    end
    local function open(row, btn)
        openedTab, gameWin = nil, nil
        local e = adminStop(row)
        if e then e.onActivate(WINS.admin) end
        local b = adminStop(btn)
        if b then b.onActivate(WINS.admin) end
        local help = b and b.help
        adminStop(row).onActivate(WINS.admin)     -- (the row again: nothing stays picked)
        return help
    end
    local own = ZeD.tr("UI_ZeD_Adm_HelpOpenOwn")
    check("the help says your own opens its card", open("adm:h:0", "adm:b:safehouse") == own)
    check("your safehouse goes to the Server tab", openedTab == "server" and gameWin == nil and K.openNext == "safe")
    draw()
    check("and its card opens", st.card and st.card.kind == "safe" and K.openNext == nil)
    TC.back(win, st)
    draw()
    check("the help names the game's window", open("adm:h:1", "adm:b:safehouse") == ZeD.tr("UI_ZeD_Adm_HelpOpenSafehouse"))
    check("someone else's safehouse: the game's window", gameWin == "safehouse" and openedTab == nil and K.openNext == nil)
    check("the help says your own opens its card", open("adm:f:0", "adm:b:faction") == own)
    check("your faction goes to the Server tab", openedTab == "server" and gameWin == nil and K.openNext == "faction")
    draw()
    check("and its card opens", st.card and st.card.kind == "faction" and K.openNext == nil)
    TC.back(win, st)
    draw()
    check("the help names the game's window", open("adm:f:1", "adm:b:faction") == ZeD.tr("UI_ZeD_Adm_HelpOpenFaction"))
    check("someone else's faction: the game's window", gameWin == "faction" and openedTab == nil and K.openNext == nil)
    ISSafehouseUI, ISFactionUI = oldS, oldF
    ZEDQA_CAPS.CanSetupSafehouses, ZEDQA_CAPS.FactionCheat = nil, nil
end

-- the HUD's war icon
do
    clearWorld()
    local got, opened = nil, true
    ISEquippedItem = { onOptionMouseDown = function(_, button) got = button.internal end }
    CC.hookWarIcon()
    ZeD_CharacterWindow.openTab = function(_, id) return opened and id == "server" end
    ISEquippedItem.onOptionMouseDown({ chr = PLAYER }, { internal = "WARMANAGERPANEL" })
    draw()
    check("the war icon opens the wars card", got == nil and st.card and st.card.kind == "wars")
    TC.back(win, st)
    draw()
    ISEquippedItem.onOptionMouseDown({ chr = PLAYER }, { internal = "ADMINPANEL" })
    check("the column's other buttons are the game's", got == "ADMINPANEL")
    opened, got = false, nil
    ISEquippedItem.onOptionMouseDown({ chr = PLAYER }, { internal = "WARMANAGERPANEL" })
    check("no tab: the game's window", got == "WARMANAGERPANEL")
end

-- a claim in flight is one claim, whatever card opens meanwhile
do
    clearWorld()
    tick(2100)
    draw()
    draw()
    REFUSE = true
    CALLS = {}
    press("srv:claim")
    press("srv:tk:sum:wars")
    TC.back(win, st)
    draw()
    check("Claim stays gray", (function()
        for _, it in ipairs(st.items) do
            if it.k == "btn" and it.id == "claim" then return it.disabled == true end
        end
        return false
    end)())
    press("srv:claim")
    local n = 0
    for _, c in ipairs(CALLS) do if c.name == "sendSafehouseClaim" then n = n + 1 end end
    check("one claim sent", n == 1, n)
    tick(9000)
    REFUSE = nil
    draw()
    draw()
    check("no answer frees it", K.claiming == nil and ZeD.Help.last == ZeD.tr("UI_ZeD_Cl_NoAnswer"), ZeD.Help.last)
end

-- Add Player with no server part: the game takes a second invitation, so ZeD does too
do
    home()
    S.forceOff = true
    press("tk:add")
    press("tk:pick:Rosa")
    settle()
    press("tk:add")
    check("still pickable, and says she was asked", stopOf("tk:pick:Rosa") ~= nil and textDrawn(ZeD.tr("UI_ZeD_Cl_InvitedWaiting")))
    CALLS = {}
    press("tk:pick:Rosa")
    check("asked again", called("sendSafehouseInvite") ~= nil)
    K.sentSure.safe = true
    S.forceOff = nil
    settle()
    press("tk:add")
    check("with the server's list she is off the drawer", stopOf("tk:pick:Rosa") == nil)
    K.sentSure = {}
    TC.back(win, st)
    draw()
end

-- the rules under the controller at the small sizes: stepping to each one brings it on screen
do
    local function reach(name)
        local list = stops("server")
        for _, e in ipairs(list) do
            if string.find(e.id, "tk:rule:", 1, true) then
                FOCUS.id, FOCUS.el, FOCUS.win = e.id, e, win
                draw()
                draw()
                draw()
                local now = stopOf(e.id)
                local sy, sh = t.sy, t.sh
                if st.card then sy, sh = t.csy, t.csh end
                check(name .. ": " .. e.id .. " comes on screen", now and now.y >= sy - 1 and now.y + now.h <= sy + sh + 1,
                    now and (now.y .. "+" .. now.h .. " in " .. sy .. "+" .. sh))
            end
        end
        FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
    end
    for _, size in ipairs({ { 360, 500, "small", false }, { 414, 560, "large", true } }) do
        ZEDQA_ROOT, ZEDQA_LARGE = 0.75, size[4]
        ZeD.applyTheme("dark", "orange", size[3])
        W, H = size[1], size[2]
        panel = newPanel(W, H)
        win._tkFields = nil
        FOCUS.pad = true
        clearWorld()
        draw()
        draw()
        reach("the tab at " .. W)
        home({ "Rosa" })
        draw()
        reach("the safehouse card at " .. W)
        TC.back(win, st)
        draw()
        press("srv:tk:sum:wars")
        draw()
        reach("the wars card at " .. W)
        TC.back(win, st)
        draw()
    end
    FOCUS.pad = false
    ZEDQA_ROOT, ZEDQA_LARGE = 1, false
    ZeD.applyTheme("dark", "orange", "small")
end

print("claim_cards_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
