-- ZeDUI/tools/qa/admin_tools_sim.lua  (Nov 7 2026, C9 to C14: the users, statistics, PvP log, climate and zones cards). The harness
-- below is log_cards_sim.lua's, taken whole; the tools' states and flows follow it.
-- (log_cards_sim.lua's header follows)
-- ZeDUI/tools/qa/log_cards_sim.lua  (Nov 6 2026, QA): the Log card with no game running.
-- The harness is admin_cards_sim.lua's: the real Tokens, Tr, Atoms, Molecules, ZeD_TicketCards, ZeD_Admin, ZeD_AdminCards, ZeD_Log,
-- ZeD_LogCards and AdminTab on Lua 5.1 stubs of a panel, text measures from the fonts' own sizes, the windows and the focus manager.
-- It draws every state of mp_log_cards.lua at Deck, 720, 1080 and 4K, Normal and Large text, mouse and pad; checks what drew (nothing
-- past the drawer's edges, no field outside its view, stops unique and whole, every grayed stop saying why), then walks the flows: the
-- Admin tab's row, the kind chips, Who, the time chips, Find, the pages, a line's buttons, Go there, the players' cards and back, the
-- ticket card's Around, Add to ticket, Clear, a refusal, the game's own PvP log with no server part. It proves the logic and the sums.
-- What it cannot prove is what the engine does: the text box, the keyboard, focus landing, real font widths.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/log_cards_sim.lua
-- It prints FAIL lines and a last line "log_cards_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]admin_tools_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- the clock, the game's globals -----------------------------------------------------------
local nowMs = 1793913240000
function getTimestampMs() return nowMs end
function getTimestamp() return math.floor(nowMs / 1000) end
function triggerEvent() end
function isClient() return true end
function isServer() return false end
function isMouseButtonDown() return false end
ZEDQA_CAPS = { TeleportToCoordinates = true, CanSeePlayersStats = true, AnswerTickets = true }
Capability = setmetatable({}, { __index = function(_, k) return k end })
local ROLE = { hasCapability = function(_, c) return ZEDQA_CAPS[c] == true end, getName = function() return "admin" end, hasAdminTool = function() return true end, hasAdminPower = function() return false end }
local PLAYER = { getUsername = function() return "Aretha" end, getX = function() return 6347.4 end, getY = function() return 5372.2 end, getZ = function() return 0 end,
    getRole = function() return ROLE end, getHoursSurvived = function() return 200 end, getSafety = function() return nil end, getPlayerNum = function() return 0 end }
function getPlayer() return PLAYER end
function getSpecificPlayer() return PLAYER end
local ONLINE = true
function getPlayerFromUsername(u) return ONLINE and { getUsername = function() return u end } or nil end
function getGameTime() return { getWorldAgeHours = function() return 270 end } end
function getSoundManager() return { playUISound = function() end } end
function getCore() return { getOptionFontSizeReal = function() return 1 end, getScreenWidth = function() return 1280 end, getScreenHeight = function() return 800 end } end
function getServerOptions() return { getOption = function() return "Knox Survivors" end, getBoolean = function() return false end, getInteger = function() return 0 end } end
function getServerName() return "Knox" end
function scoreboardUpdate() end
getCapabilities = function()
    local list = {}
    for _, n in ipairs(ZeD.Admin.qaAllCaps or {}) do list[#list + 1] = { name = function() return n end } end
    return { size = function() return #list end, get = function(_, i) return list[i + 1] end }
end
SafeHouse = { hasSafehouse = function() return nil end, getSafehouseList = function() return nil end }
Faction = { getPlayerFaction = function() return nil end, getFactions = function() return nil end }
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
TEXT.UI_Cancel, TEXT.UI_userpanel_tickets = "Cancel", "Tickets"
TEXT.IGUI_UserList_BannedIPs_Refresh = "Refresh"
TEXT.UI_Scoreboard_Teleport, TEXT.UI_Scoreboard_TeleportToYou, TEXT.UI_Scoreboard_Mute, TEXT.UI_Scoreboard_Unmute = "Teleport", "Teleport To You", "Mute", "Unmute"
TEXT.IGUI_UserList_Kick, TEXT.IGUI_UserList_Ban, TEXT.IGUI_UserList_UnBan, TEXT.IGUI_UserList_AddWarningPoint = "Kick", "Ban", "Unban", "Add Warning Points"
TEXT.IGUI_PlayerStats_UserLogs, TEXT.IGUI_PlayerStats_LevelUp, TEXT.IGUI_PlayerStats_LevelDown = "User Logs", "Level Up", "Level Down"
TEXT.IGUI_PlayerStats_ManageInventory = "Manage this player's Inventory"
TEXT.IGUI_RolesList_AddRole, TEXT.IGUI_RolesList_DeleteRole, TEXT.IGUI_RolesList_Save, TEXT.IGUI_RolesList_Up, TEXT.IGUI_RolesList_Down, TEXT.IGUI_RolesList_Edit = "Add role", "Delete role", "Save", "Up", "Down", "Edit"
TEXT.IGUI_RolesList_SetDefaultForNewUser = "Set default for New User"
TEXT.IGUI_AdminPanel_AdminPower = "Edit your Admin Powers"
TEXT.IGUI_AdminPanel_SeeServerOptions, TEXT.IGUI_AdminPanel_SandboxOptions, TEXT.IGUI_AdminPanel_PVPLogTool, TEXT.IGUI_AdminPanel_ZoneEditor = "See Server Options", "Sandbox Options", "PVP Log Tool", "Zone Editor"
TEXT.IGUI_AdminPanel_NonPvpZone, TEXT.IGUI_AdminPanel_Safezone, TEXT.IGUI_AdminPanel_ShowStatistics, TEXT.IGUI_Adm_Weather_ClimateControl = "Non PVP Zone", "Add Safezone", "Show Statistics", "Climate Control"
TEXT.IGUI_CheatPanel_Invisible, TEXT.IGUI_CheatPanel_GodMod, TEXT.IGUI_CheatPanel_NoClip = "Invisible", "God Mode", "No Clip"
TEXT.IGUI_CheatPanel_Invisible_tooltip, TEXT.IGUI_CheatPanel_GodMod_tooltip, TEXT.IGUI_CheatPanel_NoClip_tooltip = "Can't be seen or heard by other players.", "Makes you immune to all damage.", "Move through walls and collision tiles."
TEXT.IGUI_CapabilitiesTooltips_KickUser = "Player can kick other players from the server. Use /kick or /kickuser console commands."
function getText(k, ...)
    local s = TEXT[k] or k
    return s
end
getTextOrNull = function(k) return TEXT[k] end
local SENT, COMMANDS, GAME = {}, {}, {}
function sendClientCommand(p, m, c, a) SENT[#SENT + 1] = { m = m, c = c, a = a } end
function SendCommandToServer(s) COMMANDS[#COMMANDS + 1] = s end
SEND = {}
function SendCommandToServer(s) SEND[#SEND + 1] = s end
GAMECALLS = {}
local function game(name) return function(...)
    local parts = { name }
    for _, v in ipairs({ ... }) do parts[#parts + 1] = tostring(v) end
    GAMECALLS[#GAMECALLS + 1] = table.concat(parts, ":")
end end
addWarningPoint, networkUserAction, banUnbanUserAction, addRole, deleteRole, moveRole, setDefaultRoleFor = game("warn"), game("net"), game("ban"), game("addRole"), game("deleteRole"), game("moveRole"), game("default")
setupRole = function(role, desc, color, capsT)
    local n = 0
    for k, v in pairs(capsT) do if v then n = n + 1 end end
    GAMECALLS[#GAMECALLS + 1] = "setup:" .. tostring(role and role.name) .. ":" .. tostring(desc) .. ":" .. n
end
requestUsers, requestRoles, requestUserlog, getBannedIPs, getBannedSteamIDs = function() end, function() end, function() end, function() end, function() end
getUsers = function() return { size = function() return 0 end } end
getSteamModeActive = function() return false end
getCurrentUserSteamID = function() return nil end
forceDisconnect, sendPlayerExtraInfo = game("leave"), game("extra")
Color = { new = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end }
ISPlayerStatsManageInvUI = { opened = 0 }
function ISPlayerStatsManageInvUI:new() ISPlayerStatsManageInvUI.opened = ISPlayerStatsManageInvUI.opened + 1; return { initialise = function() end, addToUIManager = function() end } end
ISAdminPowerUI = { OptionList = {}, OptionById = {} }
for _, id in ipairs({ "Invisible", "GodMod", "NoClip", "UnlimitedCarry" }) do
    local o = { id = id, text = id, capability = id, value = false }
    function o:getValue() return self.value end
    function o:setValue(v) self.value = v end
    ISAdminPowerUI.OptionList[#ISAdminPowerUI.OptionList + 1] = o
    ISAdminPowerUI.OptionById[id] = o
end
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
function ISTextEntryBox:setMultipleLine() end
MASKED = setmetatable({}, { __mode = "k" })
function ISTextEntryBox:setMasked(b) MASKED[self] = b end
function ISTextEntryBox:setPlaceholderText() end
function ISTextEntryBox:setMaxTextLength(n) self.maxT = n end
-- (as the game's UITextBox2: a masked box answers getText with stars; getInternalText is what was typed)
function ISTextEntryBox:getText() if MASKED[self] then return string.rep("*", #(self.text or "")) end; return self.text end
function ISTextEntryBox:getInternalText() return self.text end
function ISTextEntryBox:isMasked() return MASKED[self] == true end
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
local STUBBED = { ["ZeD/ZeD_CharacterWindow"] = true, ["ZeD/ZeD_WorldWindow"] = true, ["ZeD/ZeD_TabPx"] = true, ["ZeD/ZeD_Messages"] = true }
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
ZeD.Messages = { ticket = function() end, ticketNew = function() end }
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
local TC, C, S, Tk = ZeD.TicketCards, ZeD.Tickets, ZeD.ServerPart, ZeD.Tk
ZeD.applyTheme("dark", "orange", "small")
check("the real files load", TC ~= nil and TABS.server ~= nil and TABS.admin ~= nil)

ZEDQA_CARDS_SIM = true

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
    if t and t.qaAfter then
        local fn = t.qaAfter
        t.qaAfter = nil
        fn(WINS[tab], stOf(tab))
        panel.texts = {}
        panel.ops = {}
        TABS[tab].render(panel, WINS[tab], 0, 0, w, h)
    end
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
    { name = "1080 Large", root = 1, size = "large", w = 552, h = 800 },
    { name = "4K Normal", root = 1.75, size = "small", w = 840, h = 1500 },
    { name = "4K Large", root = 1.75, size = "large", w = 966, h = 1500 },
    -- (no real window is this narrow: it stands in for a language with longer words)
    { name = "Narrow", root = 1, size = "large", w = 300, h = 560 },
}

-- ===========================================================================================
-- THE ADMIN TOOLS (C9 to C14): every card, every profile, mouse and pad; then the flows
-- ===========================================================================================
local M, AC, TC2 = ZeD.Admin, ZeD.AdminCards, ZeD.TicketCards
local AU, AT, AZ = ZeD.AdminUsers, ZeD.AdminTools, ZeD.AdminZones
local U, TP, Z = AU._U, AT._P, AZ._Z
check("the tools load", AU ~= nil and AT ~= nil and AZ ~= nil)
S.present, S.staff, S.admin, S.adm = true, true, true, true
M.qaHold, M.qaLink = true, false
ALLCAPS = { SeeNetworkUsers = true, ModifyNetworkUsers = true, BanUnbanUser = true, CanSeePlayersStats = true, GetStatistic = true,
    PVPLogTool = true, ChangeAndReloadServerOptions = true, TeleportToCoordinates = true, ClimateManager = true, CanSetupNonPVPZone = true,
    CanSetupSafehouses = true, SandboxOptions = true, AnswerTickets = true }
M.qaCaps = ALLCAPS
M.qaRoles = { { name = "user", desc = "", color = { r = 1, g = 1, b = 1 }, pos = 0, caps = {}, defaults = {} },
    { name = "admin", desc = "", color = { r = 1, g = 0.2, b = 0.2 }, pos = 5, caps = { CantBeBannedByUser = true }, defaults = {} } }
local function urow(user, on, role, extra)
    local r = { user = user, on = on, role = role, pos = (role == "admin") and 5 or 0, last = "2026-11-06 21:04:11", warn = 0, susp = 0, kicks = 0,
        sid = "76561198000000001", ipBan = "", sidBan = "", white = true, auth = "password", ping = on and 42 or nil, direct = true }
    for k, v in pairs(extra or {}) do r[k] = v end
    return r
end
U.qaRows = { urow("Aretha", true, "admin"), urow("Rosa", true, "user", { warn = 2, susp = 3, kicks = 1 }), urow("mike_d", false, "user", { ipBan = "10.0.0.7" }),
    urow("Kade_R", false, "user", { white = false, last = "" }) }
for i = 1, 30 do U.qaRows[#U.qaRows + 1] = urow("user" .. i, false, "user") end
U.qaMyPos = 5
TP.qaStats = { getPerformanceLocal = { ["memory-free"] = 512, fps = 59.6 }, getPerformanceRemote = { ["memory-free"] = 2048, fps = 30 },
    getNetworkLocal = { ["received-packets"] = 1200 }, getNetworkRemote = {}, getGameLocal = { players = 3 }, getGameRemote = { players = 4, ["zombies-total"] = 9000 } }
TP.qaEvents = { { s = 0, text = "mike_d hit Mags_77 with Baseball Bat", t = "2026-11-07 20:15:33", x = 10790, y = 10120, z = 0 },
    { s = 1, text = "mike_d killed Mags_77", t = "2026-11-07 20:16:02", x = 10791, y = 10121, z = 0 } }
-- a climate manager the shape the game's is (javap)
local function mkFloat(v) return { on = false, v = v, isEnableAdmin = function(s) return s.on end, setEnableAdmin = function(s, b) s.on = b end,
    getAdminValue = function(s) return s.v end, setAdminValue = function(s, x) s.v = x end } end
local function mkCol(r, g, b, a) return { getRedFloat = function() return r end, getGreenFloat = function() return g end, getBlueFloat = function() return b end, getAlphaFloat = function() return a end } end
CLIM = { floats = {}, sent = 0, calls = {} }
for i = 0, 12 do CLIM.floats[i] = mkFloat(0) end
CLIM.bool = { on = false, v = false, isEnableAdmin = function(s) return s.on end, setEnableAdmin = function(s, b) s.on = b end, getAdminValue = function(s) return s.v end, setAdminValue = function(s, b) s.v = b end }
CLIM.col = { on = false, ext = { 1, 1, 1, 1 }, int = { 0.5, 0.5, 0.5, 1 }, setEnableAdmin = function(s, b) s.on = b end,
    getAdminValue = function(s) return { getExterior = function() return mkCol(unpack(s.ext)) end, getInterior = function() return mkCol(unpack(s.int)) end } end,
    setAdminValueExterior = function(s, r, g, b, a) s.ext = { r, g, b, a } end, setAdminValueInterior = function(s, r, g, b, a) s.int = { r, g, b, a } end }
function CLIM:getClimateFloat(i) return self.floats[i] end
function CLIM:getClimateBool() return self.bool end
function CLIM:getClimateColor() return self.col end
function CLIM:getMaxWindspeedKph() return 120 end
function CLIM:transmitClientChangeAdminVars() self.sent = self.sent + 1 end
function CLIM:transmitRequestAdminVars() end
function CLIM:getWeatherPeriod() return { isRunning = function() return true end, getDuration = function() return 26 end, getTotalProgress = function() return 0.25 end } end
function CLIM:transmitStopWeather() self.calls[#self.calls + 1] = "stop" end
function CLIM:transmitTriggerStorm(d) self.calls[#self.calls + 1] = "storm:" .. d end
function CLIM:transmitTriggerTropical(d) self.calls[#self.calls + 1] = "trop:" .. d end
function CLIM:transmitTriggerBlizzard(d) self.calls[#self.calls + 1] = "bliz:" .. d end
function CLIM:transmitGenerateWeather(s, f) self.calls[#self.calls + 1] = "gen:" .. s .. ":" .. f end
TP.qaClimate = CLIM
Z.qaZones = { { title = "Market", x = 10600, y = 9900, x2 = 10650, y2 = 9950, size = 200 } }
Z.qaSafes = { { title = "Motel", owner = "Aretha", x = 6340, y = 5360, w = 20, h = 20 } }
ZPLAYER = { see = false, getX = function() return 6000.4 end, getY = function() return 5000.6 end, isSeeNonPvpZone = function(s) return s.see end,
    setSeeNonPvpZone = function(s, b) s.see = b end, checkZonesInterception = function(_, x1, x2, y1, y2) return x1 <= 10650 and x2 >= 10600 and y1 <= 9950 and y2 >= 9900 end }
Z.qaPlayer = ZPLAYER
Z.qaMap = true

local W, H = 480, 800
local win = WINS.admin
local panel = newPanel(W, H)
local st
local function draw() frame("admin", panel, W, H); st = stOf("admin") end
draw()
local function stopOf(id)
    for _, e in ipairs(stops("admin")) do if e.id == id then return e end end
    return nil
end
local function press(id)
    draw(); draw()
    local e = stopOf(id)
    check("the stop is there: " .. id, e ~= nil)
    if e then e.onActivate(win) end
    draw(); draw()
    return e
end
local function why(id)
    draw(); draw()
    local e = stopOf(id)
    return e and e.tkWhy and e.tkWhy() or nil
end
local function hasG(s) for _, v in ipairs(GAMECALLS) do if string.find(v, s, 1, true) then return true end end return false end
local function hasS(s) for _, v in ipairs(SEND) do if string.find(v, s, 1, true) then return true end end return false end
local function clear() SEND, GAMECALLS = {}, {} end
local tr = ZeD.tr
local function flash() return st.tk.flashText end

-- every state at every profile, mouse and pad -------------------------------------------------
local STATES = {
    { "users", function() AU.qaOpen(win, st, "users") end },
    { "users page 2", function() AU.qaOpen(win, st, "users"); st.card.page = 2; U.bump() end },
    { "users none", function() AU.qaOpen(win, st, "users"); st.card.find = "zzz"; U.bump() end },
    { "user", function() AU.qaOpen(win, st, "user", "Rosa") end },
    { "user pass", function() AU.qaOpen(win, st, "user", "Rosa"); st.card.open = "pass"; U.bump() end },
    { "user confirm", function() AU.qaOpen(win, st, "user", "mike_d"); st.tk.confirm = { kind = "del", from = "tk:ua:del" } end },
    { "stats", function() AT.qaOpen(win, st, "statistics") end },
    { "pvp", function() AT.qaOpen(win, st, "pvplog") end },
    { "pvp picked", function() AT.qaOpen(win, st, "pvplog"); st.card.sel = 1; TP.bump() end },
    { "climate", function() AT.qaOpen(win, st, "climate") end },
    { "zones", function() AZ.qaOpen(win, st, "zones") end },
    { "zones picked", function() AZ.qaOpen(win, st, "zones"); st.card.sel = "Market"; Z.bump() end },
    { "zones add pvp", function() AZ.qaOpen(win, st, "nonpvp"); AZ.qaArea(st, 6000, 5000, 6010, 5010) end },
    { "zones add safe", function() AZ.qaOpen(win, st, "safe") end },
}
for _, prof in ipairs(PROFILES) do
    ZEDQA_ROOT = prof.root
    ZEDQA_LARGE = prof.size == "large"
    ZeD.applyTheme("dark", "orange", prof.size)
    local p = newPanel(prof.w, prof.h)
    win._tkFields = nil
    for _, s in ipairs(STATES) do
        for _, pad in ipairs({ false, true }) do
            local name = prof.name .. (pad and " pad " or " mouse ") .. s[1]
            FOCUS.pad = pad
            FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
            st = stOf("admin")
            st.card = nil
            st.tk.confirm = nil
            local ok, err = pcall(function()
                s[2]()
                frame("admin", p, prof.w, prof.h)
                frame("admin", p, prof.w, prof.h)
                local list = verify(name, "admin", p, prof.w, prof.h)
                for _, e in ipairs(list) do
                    if e.tkWhy then
                        local w2 = e.tkWhy()
                        if w2 ~= nil then check(name .. ": a why has words " .. e.id, type(w2) == "string" and w2 ~= "" and not w2:find("^UI_ZeD_")) end
                    end
                end
                local sc = st.tk.scroll
                if sc.visible then
                    for i = 1, 4 do
                        sc:setScrollPos(i / 4)
                        frame("admin", p, prof.w, prof.h)
                        frame("admin", p, prof.w, prof.h)
                        verify(name .. " scrolled", "admin", p, prof.w, prof.h)
                    end
                    sc:setScrollPos(0)
                end
                for _, t in ipairs(p.texts) do check(name .. ": no raw key drawn", not t.s:find("UI_ZeD_"), t.s) end
            end)
            check(name .. ": draws", ok, err)
        end
    end
end
FOCUS.pad = false
ZEDQA_ROOT, ZEDQA_LARGE = 1, false
ZeD.applyTheme("dark", "orange", "small")
win._tkFields = nil
st.card = nil
draw()

-- the Admin tab: the Users row, and More tools open cards, never the game's windows ------------
check("the Users row is on the tab", stopOf("adm:tk:sum:users") ~= nil)
press("adm:tk:sum:users")
check("it opens the users card", st.card and st.card.kind == "users")
TC2.back(win, st); draw()
check("the users list is not a More tools button now", stopOf("adm:b:more:users") == nil)
for _, k in ipairs({ { "statistics", "stats" }, { "pvplog", "pvplog" }, { "climate", "climate" }, { "zones", "zones" } }) do
    st.card = nil
    press("adm:b:more:" .. k[1])
    check("More tools " .. k[1] .. " opens its card", st.card and st.card.kind == k[2], st.card and st.card.kind)
    TC2.back(win, st); draw()
    check("back lands on its button " .. k[1], st.card == nil)
end
M.qaCaps = { AnswerTickets = true }
M.bump(); draw()
check("a tool the role lacks stays gray, with why", why("adm:b:more:climate") == M.why("ClimateManager"))
check("the Users row too", why("adm:tk:sum:users") == M.why("SeeNetworkUsers"))
M.qaCaps = ALLCAPS
M.bump(); draw()

-- USERS (C9) ---------------------------------------------------------------------------------
clear()
AU.qaOpen(win, st, "users"); draw(); draw()
check("online first", st.tk.items and (function()
    for _, it in ipairs(st.tk.items) do if it.k == "arow" and it.c and it.c.id:find("^u:") then return it.c.id == "u:Aretha" end end
end)())
check("a page of 25 and a pager", stopOf("tk:unext") ~= nil and stopOf("tk:u:user30") == nil)
press("tk:unext")
check("page two", st.card.page == 2 and stopOf("tk:u:user30") ~= nil)
st.card.find = "10.0.0"; st.card.page = 1; U.bump(); draw(); draw()
check("Find reads a banned IP, as the game's filter does", stopOf("tk:u:mike_d") ~= nil and stopOf("tk:u:Rosa") == nil)
st.card.find = ""; st.card.only = true; U.bump(); draw(); draw()
check("Online only", stopOf("tk:u:Rosa") ~= nil and stopOf("tk:u:mike_d") == nil)
st.card.only = false; U.bump()
local ALLROWS = U.qaRows
U.qaRows = { ALLROWS[1], ALLROWS[2], ALLROWS[3], ALLROWS[4] }
U.bump(); draw(); draw()
check("Add user wants a name", why("tk:uaddb") == tr("UI_ZeD_Adm_WriteUserName"))
TC2._D.setField(win, "uadd", "Rosa")
check("and not one with an account", why("tk:uaddb") == tr("UI_ZeD_Adm_UserExists", "Rosa"), tostring(why("tk:uaddb")) .. " field=" .. tostring(win._tkFields and win._tkFields.uadd))
TC2._D.setField(win, "uadd", "newbie")
press("tk:uaddb")
check("Add is the game's call", hasG("net:Add:newbie:"))
check("the Bans card holds the banned lists", (function() press("tk:ubans"); return st.card.kind == "bans" end)())
TC2.back(win, st); draw()
-- one account
press("tk:u:Rosa")
check("a row opens the account", st.card.kind == "user" and st.card.user == "Rosa")
check("the game's own lines", (function()
    local all = {}
    for _, it in ipairs(st.tk.items) do all[#all + 1] = it.text or it.value or "" end
    all = table.concat(all, "|")
    return all:find("IGUI_UsersList_SuspicionPoints", 1, true) ~= nil and all:find("IGUI_UsersList_DetailsAuthType", 1, true) ~= nil
end)())
clear()
press("tk:ua:pass")
check("Reset password asks first", st.tk.confirm and st.tk.confirm.kind == "pass" and not hasG("net:ResetPassword"))
press("tk:cno")
check("Keep it says nothing to the game", st.tk.confirm == nil and not hasG("net:"))
press("tk:ua:pass"); press("tk:cyes")
check("then the game's call", hasG("net:ResetPassword:Rosa:"))
press("tk:ua:totp"); press("tk:cyes")
check("TOTP", hasG("net:ResetTOTPSecret:Rosa:"))
press("tk:upass")
check("Set password opens its field", st.card.open == "pass" and stopOf("tk:f:upass") ~= nil)
check("Set wants words", why("tk:upset") == tr("UI_ZeD_Adm_WritePass"))
TC2._D.setField(win, "upass", "hunter2")
draw(); draw()
do
    local inner = TC2._D.fieldInner(TC2._D.fieldOf(win, "upass"))
    check("the password box is masked", inner ~= nil and MASKED[inner] == true)
    -- covered (a pop-up over it): the card draws the words itself, starred
    win._drawerItem = true
    draw()
    win._drawerItem = nil
    local plain, stars = false, false
    for _, t in ipairs(panel.texts) do
        if t.s:find("hunter2", 1, true) then plain = true end
        if t.s == "*******" then stars = true end
    end
    check("a hidden password box draws stars, never the words", stars and not plain)
end
press("tk:upset")
check("SetPassword is the game's call", hasG("net:SetPassword:Rosa:hunter2") and st.card.open == nil)
-- bans on an account (the director, Nov 7): a reason and a length; without the server part the game's own call
press("tk:ua:banip")
check("Ban by IP opens its part: reason and length", st.card.open == "banip" and stopOf("tk:f:ureason") ~= nil and stopOf("tk:ul:perm") ~= nil)
check("it wants a reason", why("tk:ubyes") == tr("UI_ZeD_Adm_WriteReason"))
check("a timed length needs the server part", why("tk:ul:d1") == tr("UI_ZeD_Adm_NeedPart"))
TC2._D.setField(win, "ureason", "Duping")
press("tk:ubyes")
check("no server part: the game's call, with the reason", hasG("ban:BanIP:Rosa:Duping") and st.card.open == nil, table.concat(GAMECALLS, " "))
-- with the server part: ZeD's Bans, one record
do
    local was = getSteamModeActive
    getSteamModeActive = function() return true end
    M.qaLink = true
    SENT = {}
    clear()
    U.bump(); draw(); draw()
    press("tk:ua:banip")
    TC2._D.setField(win, "ureason", "Duping")
    press("tk:ul:perm")
    press("tk:ubyes")
    local a
    for _, e in ipairs(SENT) do if e.c == "a_ban" then a = e.a end end
    check("server part: Ban by IP is ZeD's ban on the name with its IP", a and a.user == "Rosa" and a.banIp == true and a.len == "perm" and a.reason == "Duping", a and tostring(a.len))
    check("and no game call from the client", not hasG("ban:"))
    S.routes[Tk.MOD]("t_ack", { ok = true, rid = a and a.rid })
    draw(); draw()
    SENT = {}
    press("tk:ua:bansid")
    check("Ban by Steam ID needs nobody online with the part", why("tk:ua:bansid") == nil or st.card.open == "bansid")
    TC2._D.setField(win, "ureason", "Alt")
    press("tk:ubyes")
    a = nil
    for _, e in ipairs(SENT) do if e.c == "a_ban" then a = e.a end end
    check("server part: Ban by Steam ID sends the game's own Steam ID as typed", a and a.target == "76561198000000001" and a.user == nil and a.reason == "Alt")
    S.routes[Tk.MOD]("t_ack", { ok = true, rid = a and a.rid })
    draw()
    -- the unban: ZeD's row for the account's IP ban
    M.bans = { { id = 7, user = "mike_d", banIp = true, reason = "x" } }
    TC2.back(win, st); draw()
    st.card.page = 1; U.bump(); draw()
    press("tk:u:mike_d")
    SENT = {}
    press("tk:ua:unbanip"); press("tk:cyes")
    a = nil
    for _, e in ipairs(SENT) do if e.c == "a_unban" then a = e.a end end
    check("server part: Unban by IP lifts ZeD's row", a and a.id == 7 and not hasG("ban:"))
    S.routes[Tk.MOD]("t_ack", { ok = true, rid = a and a.rid })
    M.bans = {}
    SENT = {}
    U.qaRows[2].sidBan = "76561198000000001"
    TC2.back(win, st); draw(); U.bump(); draw()
    press("tk:u:Rosa")
    press("tk:ua:unbansid"); press("tk:cyes")
    a = nil
    for _, e in ipairs(SENT) do if e.c == "a_unban" then a = e.a end end
    check("server part: a Steam ID only the game holds is lifted by ZeD's unban", a and a.sid == "76561198000000001")
    S.routes[Tk.MOD]("t_ack", { ok = true, rid = a and a.rid })
    U.qaRows[2].sidBan = ""
    M.qaLink = false
    getSteamModeActive = was
    TC2.back(win, st); draw()
    press("tk:u:Rosa")
end
-- the game's checks
U.qaMyPos = -1
st.tk.items = nil; draw(); draw()
check("an account above your role: gray with why", why("tk:ua:del") == tr("UI_ZeD_Adm_Err_rank"), tostring(why("tk:ua:del")) .. tostring(st.card.user))
U.qaMyPos = 5
TC2.back(win, st); draw()
press("tk:u:Aretha")
check("no ban on yourself", why("tk:ua:banip") == "IGUI_UserList_BanHimself")
TC2.back(win, st); draw()
st.card.page = 1; U.bump(); draw()
press("tk:u:mike_d")
check("an IP ban shows its Unban", stopOf("tk:ua:unbanip") ~= nil and stopOf("tk:ua:banip") == nil)
clear()
press("tk:ua:del"); press("tk:cyes")
check("Delete is the game's call", hasG("net:Delete:mike_d:"), table.concat(GAMECALLS, " ") .. " card=" .. tostring(st.card.kind) .. tostring(st.card.user) .. " flash=" .. tostring(flash()))
local rows = U.qaRows
local keep = {}
for _, r in ipairs(rows) do if r.user ~= "mike_d" then keep[#keep + 1] = r end end
U.qaRows = keep
draw(); draw(); draw()
check("a deleted account's card goes back with words", st.card.kind == "users" and flash() == tr("UI_ZeD_Adm_UserGone", "mike_d"), flash())
U.qaRows = rows
st.card = nil

-- STATISTICS (C13) --------------------------------------------------------------------------
TOGGLES = 0
TP.qaStats = nil
toggleStatisticsTransmission = function() TOGGLES = TOGGLES + 1 end
getPerformanceLocal = function() return { fps = 60 } end
getPerformanceRemote = function() return { fps = 31.25 } end
AT.qaOpen(win, st, "statistics"); draw(); draw()
check("the game's numbers switch on once", TOGGLES == 1, TOGGLES)
check("its number, client and server", (function()
    for _, it in ipairs(st.tk.items) do if it.k == "astat" and it.label == tr("UI_ZeD_Adm_StatFps") then return it.a == "60" and it.b == "31.2" end end
end)())
check("a number the game hasn't sent is a dash", (function()
    for _, it in ipairs(st.tk.items) do if it.k == "astat" and it.label == tr("UI_ZeD_Adm_StatRxP") then return it.a == "-" end end
end)())
press("tk:sh:net")
check("a table hides", (function() for _, it in ipairs(st.tk.items) do if it.label == tr("UI_ZeD_Adm_StatNet") then return false end end return true end)())
TC2.back(win, st); draw()
check("and off once with the card", TOGGLES == 2, TOGGLES)
AT.qaOpen(win, st, "statistics"); draw()
nowMs = nowMs + 5000
for _, fn in ipairs(Events.OnTick.list) do pcall(fn) end
check("the tab gone a while: off too", TOGGLES == 4 and TP.statsOn == false, TOGGLES)
draw()
check("and on again when the card shows", TOGGLES == 5, TOGGLES)
TC2.back(win, st); draw()

-- PVP LOG (C10) -----------------------------------------------------------------------------
clear()
AT.qaOpen(win, st, "pvplog"); draw(); draw()
check("newest first, in the Log card's lines", st.tk.items and (function()
    for _, it in ipairs(st.tk.items) do if it.k == "lline" then return it.c.id == "tk:pv:1" or it.c.id == "pv:1" end end
end)())
press("tk:pv:1")
press("tk:pvgo:1")
check("Go there is the game's teleport", hasS("/teleportto 10791,10121,0"))
press("tk:po:PVPLogToolChat")
check("Send to chat is the server's option", hasS('/changeoption PVPLogToolChat "true"'))
press("tk:pvclear")
check("Clear asks first", st.tk.confirm == true)
CLEARED = 0
clearPVPEvents = function() CLEARED = CLEARED + 1 end
press("tk:cyes")
check("then the game's clear", CLEARED == 1)
TC2.back(win, st); draw()
check("a changed option reloads the options as the game's window does", hasS("/reloadoptions"))
TP.qaEvents = {}
AT.qaOpen(win, st, "pvplog"); draw(); draw()
check("Clear with no lines: gray with why", why("tk:pvclear") == tr("UI_ZeD_Adm_PvpNone"))
TC2.back(win, st); draw()

-- CLIMATE (C12) -----------------------------------------------------------------------------
CLIM.floats[11].v = 1     -- (full daylight: no darkness)
AT.qaOpen(win, st, "climate"); draw(); draw()
check("Apply waits for a change", why("tk:capply") == tr("UI_ZeD_Adm_NothingToSave"))
press("tk:ct:wind")
press("tk:cs:wind:up")
check("a step is a twentieth", st.card.d and math.abs(st.card.d.wind.v - 6) < 1e-6, st.card.d and st.card.d.wind.v)
check("nothing reaches the game before Apply", CLIM.floats[6].on == false and CLIM.sent == 0)
press("tk:ct:precip"); press("tk:ct:snow")
press("tk:ct:temp"); press("tk:cs:temp:dn")
press("tk:ct:dark"); press("tk:cs:dark:up")
press("tk:capply")
check("Apply writes the admin values and sends once", CLIM.sent == 1 and CLIM.floats[6].on and math.abs(CLIM.floats[6].v - 0.05) < 1e-6)
check("snow follows precipitation", CLIM.bool.on == true and CLIM.bool.v == true)
check("darkness sets day, night and ambient as the game does", CLIM.floats[11].on and math.abs(CLIM.floats[11].v - 0.95) < 1e-6 and math.abs(CLIM.floats[2].v - 0.05) < 1e-6 and CLIM.floats[9].on)
check("the temperature in degrees", math.abs(CLIM.floats[4].v - (-4)) < 1e-6, CLIM.floats[4].v)
check("the card reads the game again", st.card.d == nil and st.card.live.wind.on == true)
press("tk:ct:fog")
press("tk:crevert")
check("Revert drops the draft", st.card.d == nil)
press("tk:wstorm")
check("a storm for its length", CLIM.calls[#CLIM.calls] == "storm:24")
press("tk:wf:1"); press("tk:wgen")
check("a cold front", CLIM.calls[#CLIM.calls] == "gen:0.8:1", CLIM.calls[#CLIM.calls])
TC2.back(win, st); draw()

ZeD_WorldWindow.openTab = function() return true end
-- ZONES (C14) -------------------------------------------------------------------------------
NPZ = {}
NonPvpZone.addNonPvpZone = function(t, a, b, c, d) NPZ[#NPZ + 1] = "add:" .. t .. ":" .. a .. "," .. b .. "," .. c .. "," .. d end
NonPvpZone.removeNonPvpZone = function(t) NPZ[#NPZ + 1] = "remove:" .. t end
sendSafezoneClaim = function(o, x, y, w, h, t) NPZ[#NPZ + 1] = "claim:" .. o .. ":" .. x .. "," .. y .. "," .. w .. "," .. h .. ":" .. t end
AZ.qaOpen(win, st, "zones"); draw(); draw()
press("tk:z:1")
press("tk:zgo:1")
check("Go there is the zone's middle", hasS("/teleportto 10625,9925,0"))
press("tk:zdel:1"); press("tk:cyes")
check("Remove asks, then the game's call", NPZ[#NPZ] == "remove:Market")
press("tk:zsee")
check("See zones on the ground", ZPLAYER.see == true)
press("tk:zaddpvp")
check("adding: a name ready", st.card.add == "nonpvp" and TC2._D.fieldText(win, "zname") == tr("UI_ZeD_Adm_ZoneDefault", 2))
check("Add waits for an area", why("tk:zadd") == tr("UI_ZeD_Adm_ZoneNoArea"))
press("tk:zc1")
check("one corner is too small", why("tk:zadd") == tr("UI_ZeD_Adm_ZoneTooSmall"))
AZ.qaArea(st, 10620, 9920, 10700, 9990)
check("an overlap says the game's words", why("tk:zadd") == "IGUI_PvpZone_ZoneInterception")
AZ.qaArea(st, 6010, 5020, 6000, 5000)
press("tk:zadd")
check("Add is the game's call, the corners in order", NPZ[#NPZ] == "add:Zone #2:6000,5000,6010,5020", NPZ[#NPZ])
-- the map pick
press("tk:zaddsafe")
press("tk:zmap")
check("Pick on the map arms the pick", Z.pick ~= nil and Z.pick.card == st.card)
local ext
for _, d in ipairs(ZeD.MapsTabExt.list) do if d.id == "admin_zones" then ext = d end end
local MP = { mapAPI = { uiToWorldX = function(_, x) return 6000 + x end, uiToWorldY = function(_, x, y) return 5000 + y end,
    worldToUIX = function(_, x) return x - 6000 end, worldToUIY = function(_, x, y) return y - 5000 end }, drawRect = function() end, drawRectBorder = function() end }
check("the map knows it is armed", ext and ext.armed(win) == true and ext.banner(win) == tr("UI_ZeD_Adm_ZoneBanner"))
ext.mouseDown(MP, win, 30, 40); ext.mouseMove(MP, win, 50, 45); ext.drawMap(MP, win); ext.mouseUp(MP, win, 12, 70)
check("a drag sets the area", Z.pick == nil and st.card.area and st.card.area.x1 == 6030 and st.card.area.y2 == 5070)
check("a safe zone wants its owner", why("tk:zadd") == tr("UI_ZeD_Adm_ZoneWriteOwner"))
TC2._D.setField(win, "zowner", "Rosa")
press("tk:zadd")
check("the claim is the game's call", NPZ[#NPZ] == "claim:Rosa:6012,5040,19,31:Safezone #2", NPZ[#NPZ])
check("controller A: down, hold, up", (function()
    press("tk:zaddsafe"); press("tk:zmap")
    ext.padA(MP, win, 0, 0, "down"); ext.padA(MP, win, 5, 5, "hold"); ext.padA(MP, win, 9, 9, "up")
    return st.card.area and st.card.area.x2 == 6009
end)())
TC2.back(win, st); draw()
check("leaving takes the ground highlight off", ZPLAYER.see == false)

-- SERVER SANDBOX OPTIONS (C11): the in-game window's Apply on a server sends a copy, as ISServerSandboxOptionsUI does ---------
do
    LOADED["ZeD/ZeD_MainMenuSandbox"], LOADED["ZeD/ZeD_SandboxNotes"] = true, true
    ZeD.MainMenu = { U = {}, ui = {}, now = function() return nowMs end, clickSound = function() end, ctx = {} }
    ZeD.SandboxNotes = {}
    ZeD_MMSandbox = { derive = function(self, name) local o = { Type = name }; setmetatable(o, { __index = self }); return o end }
    local function opt(v) return { v = v, parse = function(o, x) o.v = x end, getValueAsString = function(o) return o.v end, isValidString = function() return true end } end
    local live = { n = opt("1") }
    local TOLUA, SENT2 = 0, {}
    local function opts(store)
        return { getOptionByName = function(_, n) return store[n] end, toLua = function() TOLUA = TOLUA + 1 end, getDayLengthMinutes = function() return 60 end }
    end
    local LIVE = opts(live)
    getSandboxOptions = function() return LIVE end
    SandboxOptions = { new = function()
        local copy = {}
        local o = opts(copy)
        o.copyValuesFrom = function(_, from) for k, v in pairs(live) do copy[k] = opt(v.v) end end
        o.sendToServer = function() SENT2[#SENT2 + 1] = copy.n.v end
        return o
    end }
    IsoWorld = { parseDistributions = function() end }
    StoryClutter = { Init = function() end }
    ModData = { getOrCreate = function() return {} end }
    getGameTime = function() return { getYear = function() return 1993 end, getMonth = function() return 6 end, getDay = function() return 9 end,
        getHour = function() return 8 end, getMinutes = function() return 0 end } end
    local fn = assert(loadfile(ROOT .. "42/media/lua/client/ZeD/ZeD_SandboxInGame.lua"))
    fn()
    local row = { name = "n" }
    local function mk(server)
        local w = setmetatable({ server = server, base = { n = "1" }, diff = { n = true }, nDiff = 1 }, { __index = ZeD_MMSandboxIG })
        w.commitCell = function() end
        w.refreshDiff = function() end
        w.allRows = function() return { row } end
        w.rowValue = function() return "4" end
        w.load = function() end
        return w
    end
    local w = mk(true)
    ZeD.MainMenu.pauseSandbox = w
    w:applyNow()
    check("server: the changes go to the server on a copy", SENT2[1] == "4" and live.n.v == "1", tostring(SENT2[1]) .. " " .. live.n.v)
    check("server: the client's own options are not written", TOLUA == 0)
    check("server: the base moves to what was sent", w.base.n == "4")
    check("server: History is the session's, not the save's", #ZeD.SandboxIG.history() == 1)
    check("server: the note says sent", w._note == ZeD.tr("UI_ZeD_Sbx_SentServer", ZeD.tr("UI_ZeD_Sbx_Count1")), w._note)
    local sp = mk(false)
    ZeD.MainMenu.pauseSandbox = sp
    sp:applyNow()
    check("single player still writes its own options", TOLUA == 1 and live.n.v == "4" and #SENT2 == 1)
end

print("admin_tools_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
